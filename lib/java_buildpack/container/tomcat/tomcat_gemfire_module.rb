# Encoding: utf-8
# Cloud Foundry Java Buildpack
# Copyright 2013 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'java_buildpack/component/versioned_dependency_component'
require 'java_buildpack/container'
require 'java_buildpack/container/tomcat/tomcat_utils'
require 'java_buildpack/logging/logger_factory'
require 'rexml/document'
require 'rexml/formatters/pretty'

module JavaBuildpack
  module Container

    # Encapsulates the detect, compile, and release functionality for Tomcat lifecycle support.
    class TomcatGemfireModule < JavaBuildpack::Component::VersionedDependencyComponent
      include JavaBuildpack::Container

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
        if supports?
          download(@version, @uri) { |file| expand file }
          mutate_configuration
        end
      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release
      end

      protected

      # (see JavaBuildpack::Component::VersionedDependencyComponent#supports?)
      def supports?
        @application.services.one_service? FILTER, KEY_HOST_NAME, KEY_PORT
      end

      private

      FILTER = /p-gemfire/.freeze

      FLUSH_VALVE_CLASS_NAME = 'com.gopivotal.manager.SessionFlushValve'.freeze

      KEY_HOST_NAME = 'host'.freeze

      KEY_PASSWORD = 'password'.freeze

      KEY_PORT = 'port'.freeze

      GEMFIRE_MANAGER_CLASS_NAME = 'com.gemstone.gemfire.modules.session.catalina.Tomcat7DeltaSessionManager'.freeze

      GEMFIRE_LISTENER_CLASS_NAME = 'com.gemstone.gemfire.modules.session.catalina.ClientServerCacheLifecycleListener'.freeze

      private_constant :FILTER, :KEY_HOST_NAME, :KEY_PASSWORD, :KEY_PORT

      def add_manager(context)
        context.add_element 'Manager', 'className' => GEMFIRE_MANAGER_CLASS_NAME
      end

      def add_listener(context)
        context.add_element 'Listener', 'className' => GEMFIRE_LISTENER_CLASS_NAME
      end

      def add_locator(context)
        credentials = @application.services.find_service(FILTER)['credentials']

        context.delete_element 'server'
        context.add_element 'locator', 'host'    => credentials[KEY_HOST_NAME],
                                       'port'    => credentials[KEY_PORT]
      end

      def context_xml
        @droplet.sandbox + 'conf/context.xml'
      end

      def server_xml
        @droplet.sandbox + 'conf/server.xml'
      end

      def cache_xml
        @droplet.sandbox + 'conf/cache-client.xml'
      end

      def change_file(hash)
        formatter         = REXML::Formatters::Pretty.new(4)
        formatter.compact = true
        hash.each do |fileChange, document|
          fileChange.open('w') do |file|
            formatter.write document, file
            file << "\n"
          end
        end
      end

      def expand(file)
        with_timing "Expanding Tomcat gemfire session to #{@droplet.sandbox.relative_path_from(@droplet.root)}" do
          FileUtils.mkdir_p @droplet.sandbox
          shell "tar xzf #{file.path} -C #{@droplet.sandbox} 2>&1"
        end

      end

      def mutate_configuration
        puts '       Adding GemFire Session Replication'

        context_document = context_xml.open { |file| REXML::Document.new file }
        server_document = server_xml.open { |file| REXML::Document.new file }
        cache_client_document = cache_xml.open { |file| REXML::Document.new file }

        context  = REXML::XPath.match(context_document, '/Context').first
        server = REXML::XPath.match(server_document, '/Server').first
        cache = REXML::XPath.match(cache_client_document, '/client-cache/pool').first

        add_manager context
        add_listener server
        add_locator cache

        hash = { context_xml => context_document, server_xml => server_document, cache_xml => cache_client_document }
        change_file hash

      end
    end
  end
end

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

require 'java_buildpack/component/modular_component'
require 'java_buildpack/container'
#require 'java_buildpack/container/tomcat/tomcat_insight_support'
require 'java_buildpack/container/tcserver/tcserver_instance'
require 'java_buildpack/container/tcserver/tcserver_lifecycle_support'
require 'java_buildpack/container/tcserver/tcserver_logging_support'
#require 'java_buildpack/container/tomcat/tomcat_redis_store'
require 'java_buildpack/util/java_main_utils'

module JavaBuildpack
  module Container

    # Encapsulates the detect, compile, and release functionality for Tomcat applications.
    class Tcserver < JavaBuildpack::Component::ModularComponent

      protected

      # (see JavaBuildpack::Component::ModularComponent#command)
      def command
        @droplet.java_opts.add_system_property 'http.port', '$PORT'

        [
          "JAVA_ENDORSED_DIRS=$PWD/#{(@droplet.sandbox + 'tcserver/endorsed').relative_path_from(@droplet.root)}",
          @droplet.java_home.as_env_var,
          @droplet.java_opts.as_env_var,
          "$PWD/#{(@droplet.sandbox + 'tcserver/bin/tcruntime-ctl.sh').relative_path_from(@droplet.root)}",
          #"$PWD/#{(@droplet.sandbox + 'tcserver').relative_path_from(@droplet.root)}",
          'start'
        ].flatten.compact.join(' ')
      end

      # (see JavaBuildpack::Component::ModularComponent#sub_components)
      def sub_components(context)
        [
          TcserverInstance.new(sub_configuration_context(context, 'tcserver')),
          TcserverLifecycleSupport.new(sub_configuration_context(context, 'lifecycle_support')),
          TcserverLoggingSupport.new(sub_configuration_context(context, 'logging_support')),
#          TomcatRedisStore.new(sub_configuration_context(context, 'redis_store')),
#          TomcatInsightSupport.new(context)
        ]
      end

      # (see JavaBuildpack::Component::ModularComponent#supports?)
      def supports?
        web_inf? && !JavaBuildpack::Util::JavaMainUtils.main_class(@application)
      end

      private

      def web_inf?
        (@application.root + 'WEB-INF').exist?
      end

    end

  end
end

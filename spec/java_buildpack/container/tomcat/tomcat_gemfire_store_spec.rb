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

require 'spec_helper'
require 'component_helper'
require 'java_buildpack/container/tomcat/tomcat_gemfire_store'

describe JavaBuildpack::Container::TomcatGemfireStore do
  include_context 'component_helper'

  let(:component_id) { 'tomcat' }

  let(:configuration) do
    { 'database'             => 'test-database',
      'timeout'              => 'test-timeout',
      'connection_pool_size' => 'test-connection-pool-size' }
  end

  it 'should not detect without a session-replication service' do
    expect(component.detect).to be_nil
  end

  context do

    before do
      allow(services).to receive(:one_service?).with(/session-gemfire-replication/, 'locator', 'port')
                         .and_return(true)
      allow(services).to receive(:find_service).and_return('credentials' => { 'locator' => 'test-host',
                                                                              'port'     => 'test-port' })
    end

    it 'should detect with a session-replication service' do
      expect(component.detect).to eq("tomcat-gemfire-store=#{version}")
    end

    it 'should copy resources',
       app_fixture:   'container_tomcat_gemfire_store',
       cache_fixture: 'stub-gemfire-store.tar.gz' do

      component.compile

      expect(sandbox + 'lib/test.jar').to exist
      expect(sandbox + 'conf/cache-client.xml').to exist
    end

    it 'should changed context.xml',
       app_fixture:   'container_tomcat_gemfire_store',
       cache_fixture: 'stub-gemfire-store.tar.gz' do

      component.compile

      expect((sandbox + 'conf/context.xml').read)
      .to eq(Pathname.new('spec/fixtures/container_tomcat_gemfire_store_context_after.xml').read)

    end

    it 'should changed server.xml',
       app_fixture:   'container_tomcat_gemfire_store',
       cache_fixture: 'stub-gemfire-store.tar.gz' do

      component.compile

      expect((sandbox + 'conf/server.xml').read)
      .to eq(Pathname.new('spec/fixtures/container_tomcat_gemfire_store_server_after.xml').read)

    end

    it 'should changed cache-client.xml',
       app_fixture:   'container_tomcat_gemfire_store',
       cache_fixture: 'stub-gemfire-store.tar.gz' do

      component.compile

      expect((sandbox + 'conf/cache-client.xml').read)
      .to eq(Pathname.new('spec/fixtures/container_tomcat_gemfire_store_cache_client_after.xml').read)

    end
  end

  it 'should do nothing during release' do
    component.release
  end

end

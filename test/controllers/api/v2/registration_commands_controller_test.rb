require 'test_helper'

class Api::V2::RegistrationCommandsControllerTest < ActionController::TestCase
  describe 'generate' do
    test 'without params' do
      post :create
      assert_response :success
      response = ActiveSupport::JSON.decode(@response.body)['registration_command']

      assert_includes response, "curl --silent --show-error   'http://test.host/register'"
      assert_includes response, "--header 'Authorization: Bearer"
    end

    test 'with params' do
      params = {
        organization_id: taxonomies(:organization1).id,
        location_id: taxonomies(:location1).id,
        hostgroup_id: hostgroups(:common).id,
        operatingsystem_id: operatingsystems(:redhat).id,
        setup_insights: false,
        setup_remote_execution: false,
        packages: 'pkg1',
        update_packages: true,
      }

      post :create, params: params
      assert_response :success

      response = ActiveSupport::JSON.decode(@response.body)['registration_command']
      assert_includes response, "organization_id=#{taxonomies(:organization1).id}"
      assert_includes response, "location_id=#{taxonomies(:location1).id}"
      assert_includes response, "hostgroup_id=#{hostgroups(:common).id}"
      assert_includes response, "operatingsystem_id=#{operatingsystems(:redhat).id}"
      assert_includes response, 'setup_insights=false'
      assert_includes response, 'setup_remote_execution=false'
      assert_includes response, 'packages=pkg1'
      assert_includes response, 'update_packages=true'
    end

    test 'with params ignored in URL' do
      features = [FactoryBot.create(:feature, name: 'Registration'), FactoryBot.create(:feature, name: 'Templates')]
      proxy = FactoryBot.create(:smart_proxy, features: features)
      params = {
        insecure: true,
        jwt_expiration: 23,
        smart_proxy_id: proxy.id,
      }

      post :create, params: params
      assert_response :success

      response = ActiveSupport::JSON.decode(@response.body)['registration_command']
      assert_includes response, "curl --silent --show-error  --insecure '#{proxy.url}/register'"
    end

    test 'os without host_init_config template' do
      os = FactoryBot.create(:operatingsystem)
      os.os_default_templates = []

      post :create, params: { operatingsystem_id: os.id}
      assert_response :unprocessable_entity
    end

    test 'with proxy without required features' do
      post :create, params: { smart_proxy_id: smart_proxies(:one).id }
      assert_response :unprocessable_entity
    end

    test 'using wget' do
      params = {
        download_utility: 'wget',
      }

      post :create, params: params
      assert_response :success

      response = ActiveSupport::JSON.decode(@response.body)['registration_command']
      assert_includes response, "wget --no-verbose --no-hsts --output-document -  'http://test.host/register?download_utility=wget'"
      assert_includes response, "--header 'Authorization: Bearer"
    end

    test 'using wget with insecure option' do
      params = {
        download_utility: 'wget',
        insecure: true,
      }

      post :create, params: params
      assert_response :success

      response = ActiveSupport::JSON.decode(@response.body)['registration_command']
      assert_includes response, "wget --no-verbose --no-hsts --output-document - --no-check-certificate 'http://test.host/register?download_utility=wget'"
      assert_includes response, "--header 'Authorization: Bearer"
    end
  end
end

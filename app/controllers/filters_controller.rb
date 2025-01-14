class FiltersController < ApplicationController
  include Foreman::Controller::AutoCompleteSearch
  include Foreman::Controller::Parameters::Filter

  before_action :find_role
  before_action :setup_search_options, :only => :index

  def index
    @filters = resource_base.unscoped.includes(:role, :permissions).search_for(params[:search], :order => params[:order])
    @filters = @filters.paginate(:page => params[:page], :per_page => params[:per_page]) unless params[:paginate] == 'client'
    @roles_authorizer = Authorizer.new(User.current, :collection => @filters.map(&:role_id))
  end

  def create
    @filter = Filter.new(filter_params)
    if @filter.save
      process_success :success_redirect => saved_redirect_url_or(filters_path(:role_id => @role))
    else
      process_error
    end
  end

  def update
    @filter = resource_base.find(params[:id])
    if @filter.update(filter_params)
      process_success :success_redirect => saved_redirect_url_or(filters_path(:role_id => @role))
    else
      process_error
    end
  end

  def destroy
    @filter = resource_base.find(params[:id])
    if @filter.destroy
      process_success :success_redirect => saved_redirect_url_or(filters_path(:role_id => @role))
    else
      process_error
    end
  end

  def disable_overriding
    @filter = resource_base.find(params[:id])
    @filter.disable_overriding!
    process_success :success_msg => _('Filter overriding has been disabled')
  end

  private

  def action_permission
    case params[:action]
      when 'disable_overriding'
        'edit'
      else
        super
    end
  end

  def find_role
    @role = Role.find_by_id(role_id)
  end

  def role_id
    params[:role_id]
  end

  def setup_search_options
    @original_search_parameter = params[:search]
    params[:search] ||= ""
    params.each do |param, value|
      case param
      when /role_id$/
        if (role = Role.find_by_id(value)).present?
          query = "role_id = #{role.id}"
          params[:search] += query unless params[:search].include? query
        end
      when /(\w+)_id$/
        if value.present?
          query = "#{Regexp.last_match(1)} = #{value}"
          params[:search] += query unless params[:search].include? query
        end
      end
    end
  end
end

class HostCounter
  def initialize(association)
    @association = association
  end

  delegate :fetch, to: :hosts_count

  def [](instance)
    hosts_count[instance&.id] || 0
  end

  def hosts_count
    # Use caching to save recounts in case new counters are created in
    # quick succession, e.g. from CSV export or child hostgroup counts
    cache do
      counted_hosts
    end
  end

  private

  def cache(&block)
    delay = Rails.env.test? ? 0 : 2.minutes
    Rails.cache.fetch("hosts_count/#{@association}/#{User.current.id}", expires_in: delay, &block)
  end

  def counted_hosts
    hosts_scope = Host::Managed.reorder('')
    grouping = "#{@association}_id"
    case @association.to_s
    when 'organization', 'location'
      # If we are on /organizations or /locations, this allows to display the
      # count for hosts not in the current organization & location.
      hosts_scope = hosts_scope.unscoped
    when 'subnet', 'domain'
      hosts_scope = hosts_scope.joins(:primary_interface)
      grouping.prepend("#{Nic::Base.table_name}.")
    end
    hosts_scope.authorized(:view_hosts).group(ActiveRecord::Base.sanitize_sql(grouping)).count
  end
end

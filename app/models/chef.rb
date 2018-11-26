require "google/cloud/datastore"


class Chef
  attr_accessor :id, :user_id, :group_id, :user_name, :alias_name, :count

  def self.dataset
    @dataset ||= Google::Cloud::Datastore.new(
      project_id: Rails.application.config.
      database_configuration[Rails.env]["dataset_id"]
    )
  end

  def self.query options = {}
    query = Google::Cloud::Datastore::Query.new
    query.kind "Chef"
    query.limit options[:limit]   if options[:limit]
    query.cursor options[:cursor] if options[:cursor]

    results = dataset.run query
    chefs   = results.map {|entity| Chef.from_entity entity }

    if options[:limit] && results.size == options[:limit]
      next_cursor = results.cursor
    end

    return chefs, next_cursor
  end

  def self.from_entity entity
    chef = Chef.new
    chef.id = entity.key.id
    entity.properties.to_hash.each do |name, value|
      chef.send "#{name}=", value if chef.respond_to? "#{name}="
    end
    chef
  end

  def self.find id
    query    = Google::Cloud::Datastore::Key.new "Chef", id.to_i
    entities = dataset.lookup query

    from_entity entities.first if entities.any?
  end

  def self.find_by_user_id user_id
    query = dataset.query("Chef").where("user_id", "=", user_id)
    entities = dataset.run query
    from_entity entities.first if entities.any?
  end

  def self.find_by_group_id group_id
    query = dataset.query("Chef").where("group_id", "=", group_id)
    entities = dataset.run query
    entities
  end

  include ActiveModel::Model

  def save
    if valid?
      entity = to_entity
      Chef.dataset.save entity
      self.id = entity.key.id
      true
    else
      false
    end
  end

  def to_entity
    entity                 = Google::Cloud::Datastore::Entity.new
    entity.key             = Google::Cloud::Datastore::Key.new "Chef", id
    entity["user_id"]      = user_id
    entity["group_id"]     = group_id if group_id
    entity["user_name"]    = user_name
    entity["alias_name"]   = alias_name if alias_name
    entity["count"]        = count
    entity
  end

  include ActiveModel::Validations

  def update attributes
    attributes.each do |name, value|
      send "#{name}=", value if respond_to? "#{name}="
    end
    save
  end

  def destroy
    Chef.dataset.delete Google::Cloud::Datastore::Key.new "Chef", id
  end

  def persisted?
    id.present?
  end
end

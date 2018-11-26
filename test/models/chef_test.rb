require 'test_helper'

class ChefTest < ActiveSupport::TestCase
  test "new save" do
    p c = Chef.new({user_id: 2, group_id: 3, user_name: 4, alias_name: 4, count: 6})
  end

  test "update" do
    p c = Chef.find("5630742793027584")
    p c.user_name = "aaaaaa"
    p c.count = "10"
    p c.save
  end
end

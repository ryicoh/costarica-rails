require 'test_helper'

class ChefTest < ActiveSupport::TestCase
  test "new save" do
    p c = Chef.new({user_id: 3, group_id: 3, user_name: 4, alias_name: 4, count: 6})
    p c.save
  end

  test "update" do
    p c = Chef.find("5630742793027584")
    p c.user_name = "aaaaaa"
    p c.count = "10"
    p c.save
  end

  test "find_by_user_id" do
    p Chef.find_by_user_id 'U1c370732c129efed16ee9b085ff6dfa1'
  end

  test "find_by_group_id" do
    assert(Chef.find_by_group_id(3).size, 4)
  end

end

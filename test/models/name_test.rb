require "test_helper"

class NameTest < ActiveSupport::TestCase
  test "loads all names from JSON" do
    assert Name.all.any?
  end

  test "find returns a name by string" do
    name = Name.find("Martín")

    assert_equal "Martín", name.name
    assert_equal "male", name.gender
  end

  test "filters by gender" do
    assert Name.male.all? { |n| n.gender == "male" }
    assert Name.female.all? { |n| n.gender == "female" }
    assert Name.neutral.all? { |n| n.gender == "neutral" }
  end

  test "is immutable" do
    name = Name.find("Martín")

    assert name.frozen?
    assert name.name.frozen?
  end

  test "equality is based on name and gender" do
    name1 = Name.new(name: "Test", gender: "male")
    name2 = Name.new(name: "Test", gender: "male")

    assert_equal name1, name2
  end
end

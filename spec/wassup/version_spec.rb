RSpec.describe Wassup::VERSION do
  it "is a string" do
    expect(Wassup::VERSION).to be_a(String)
  end

  it "follows semantic versioning format" do
    expect(Wassup::VERSION).to match(/^\d+\.\d+\.\d+$/)
  end

  it "is not empty" do
    expect(Wassup::VERSION).not_to be_empty
  end
end
RSpec.describe Wassup do
  it "has a version number" do
    expect(Wassup::VERSION).not_to be nil
  end

  it "defines the Error class" do
    expect(Wassup::Error).to be < StandardError
  end

  it "has all expected module constants" do
    expect(defined?(Wassup::App)).to be_truthy
    expect(defined?(Wassup::Color)).to be_truthy
    expect(defined?(Wassup::Pane)).to be_truthy
    expect(defined?(Wassup::PaneBuilder)).to be_truthy
    expect(defined?(Wassup::AlertLevel)).to be_truthy
  end
end

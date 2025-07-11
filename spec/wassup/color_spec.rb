RSpec.describe Wassup::Color do
  before do
    allow(Curses).to receive(:use_default_colors)
    allow(Curses).to receive(:init_pair)
  end

  describe ".init" do
    it "initializes color pairs" do
      expect(Curses).to receive(:use_default_colors)
      expect(Curses).to receive(:init_pair).at_least(:once)
      
      Wassup::Color.init
    end
  end

  describe "#initialize" do
    it "initializes with a color name" do
      color = Wassup::Color.new("red")
      expect(color.color_pair).to eq(Wassup::Color::Pair::RED)
    end

    it "initializes with a numeric string" do
      color = Wassup::Color.new("5")
      expect(color.color_pair).to eq(5)
    end

    it "defaults to white for unknown colors" do
      color = Wassup::Color.new("unknown")
      expect(color.color_pair).to eq(Wassup::Color::Pair::WHITE)
    end
  end

  describe "color constants" do
    it "defines all expected color pairs" do
      expect(Wassup::Color::Pair::BLACK).to eq(0)
      expect(Wassup::Color::Pair::BLUE).to eq(1)
      expect(Wassup::Color::Pair::CYAN).to eq(2)
      expect(Wassup::Color::Pair::GREEN).to eq(3)
      expect(Wassup::Color::Pair::MAGENTA).to eq(4)
      expect(Wassup::Color::Pair::RED).to eq(5)
      expect(Wassup::Color::Pair::WHITE).to eq(15)
      expect(Wassup::Color::Pair::YELLOW).to eq(7)
      expect(Wassup::Color::Pair::NORMAL).to eq(20)
      expect(Wassup::Color::Pair::HIGHLIGHT).to eq(21)
      expect(Wassup::Color::Pair::GRAY).to eq(22)
    end
  end
end
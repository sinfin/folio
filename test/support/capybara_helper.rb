class Capybara::Node::Element
  def html
    native.to_html
  end
end

class Capybara::Node::Simple
  def html
    native.to_html
  end
end

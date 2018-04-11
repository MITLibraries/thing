module LinkHelper
  # helper wrapper around link_to that inserts visual and screen reader info
  # for navigation links
  def nav_link_to(name, url)
    link_name = link_name(name, url)
    link_to(link_name, url, class: link_class(url))
  end

  private

  # Includes screen reader span if current page
  def link_name(name, url)
    return name unless current_page?(url)
    "#{name}<span class='sr'> current page</span>".html_safe
  end

  # Includes css `current` class if current page
  def link_class(url)
    return 'nav-item' unless current_page?(url)
    'nav-item current'
  end
end

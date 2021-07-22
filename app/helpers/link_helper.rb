module LinkHelper
  # helper wrapper around link_to that inserts visual and screen reader info
  # for navigation links
  def nav_link_to(name, url)
    link_to(name, url,
            class: link_class(url),
            'aria-current': aria_current?(url))
  end

  private

  # Includes css `current` class if current page
  def link_class(url)
    return 'nav-item' unless current_page?(url)

    'nav-item current'
  end

  # Includes css `current` class if current page
  def aria_current?(url)
    return 'page' if current_page?(url)
  end
end

# subscribe.d

This site hosts versioned automatically-generated documentation for the project. See the [GitHub repository page](https://github.com/v--/subscribed) for an introduction.

{% assign files = site.static_files | where_exp: 'file', 'file.name == "subscribed.html"' | sort: 'path' %}
<ul>
  {% for file in files %}
    <li><a href="/subscribed{{ file.path }}">{{ file.path | remove: '/docs/' | remove: '/subscribed.html' }}</a></li>
  {% endfor %}
</ul>

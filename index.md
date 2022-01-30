# subscribe.d

This site hosts versioned documentation for the project. See the [GitHub repository page](https://github.com/v--/subscribed) for an introduction.

{% assign doclist = site.static_files | sort: 'url'  %}
<ul>
  {% for doc in doclist %}
    <li><a href="{{ site.baseurl }}{{ doc.url }}">{{ doc.url }}</a></li>
  {% endfor %}
</ul>

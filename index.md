# subscribe.d

{% assign doclist = site.pages | sort: 'url'  %}
<ul>
  {% for doc in doclist %}
    <li><a href="{{ site.baseurl }}{{ doc.url }}">{{ doc.url }}</a></li>
  {% endfor %}
</ul>

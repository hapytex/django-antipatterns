% Filtering in the template
---
severity: 3
type: antipattern
typefa: "fas fa-ban"
tags: [filter, template, database-query, views]
layers: [views, templates]
---

Instead of filtering data in the view, we can filter data in the template.
For example with:

<pre class="django"><code>{% for product in products %}
    {% if <b>product.is_active</b> %}
        {{ product.name }}
    {% endif %}
{% endfor %}</code></pre>

Here we thus enumerate over the products in `product`, check if it is an active
product, and only then we render the `.name` of the `product`.

# Why is it a problem?

Templates should not be concerned with *business logic*, they should only
implement *rendering* logic. Templates thus try to let data look pleasant
on the screen, but they should not decide what that data is, that is the
responsibility of the *view*.

It is less efficient to let the template do this. It means that you first load
all `Product`s into memory, pass these to the template, and then the template
will have to decide what to render or not. The template engine is not that fast,
and could thus easily go into timeout if the number of products is large.

One often filters on related models as well, for example:

<pre class="django"><code>{% for product in products %}
    {% if <b>product.category.is_active</b> %}
        {{ product.name }}
    {% endif %}
{% endfor %}</code></pre>

This will make extra queries in the template, and thus turn into a *N+1*
problem.

# What can be done to resolve the problem?

One should filter in the *view*. Django's ORM makes filtering easier and more
efficient. the filtering is done at the *database side*, and a database is
designed to do this efficient. It will not generate *N+1* problems if you filter
on related objects, and furthermore it will reduce the bandwidth between the
database and the Django/Python layer.

Instead of filtering the `products` in the template, we thus filter in the view:

<pre class="python"><code>from django.shortcuts import render

def my_view(request):
    # &hellip;
    products = Product.objects.<b>filter(is_active=True)</b>
    # &hellip;
    context = {
        'products': products
    }
    return render(request, <i>'some_template.html'</i>, context)</code></pre>

then we can render the active products with:

<pre class="django"><code>{% for product in products %}
    {{ product.name }}
{% endfor %}</code></pre>

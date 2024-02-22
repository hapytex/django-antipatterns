% calling `all()` before `count()` or `filter()` etc.
---
severity: 2
type: antipattern
typefa: "fas fa-ban"
tags: [queryset]
layers: [views, orm]
solinks: []
---

Often when one wants to determine how many objects are there in a Django model, they do so with:

<pre class="python"><code>from .models import Project

def my_view(request):
    project_count = Project.objects.all().count()
    return render(request, '<i>name-of-some-template.html</i>', {'count': project_count})</code></pre>

Or filter objects based on a given codition like so:

<pre class="python"><code>from .models import Project

def my_view(request):
    projects = Project.objects.all().filter(user=request.user)
    return render(request, '<i>name-of-some-template.html</i>', {'projects': projects})</code></pre>


# Why is it a problem?

When you call `all()` before `filter`, you essentially, are actually constructing your queryset twice with one not being needed here. `filter` returns a new queryset already that contains objects matching the condition so need of `all()`.

Simillarly, calling `all()` before `count()` is not neccessary because `count()` already does a  `SELECT COUNT(*)` at the database level.

# What can be done to resolve the problem?

Simply get rid of the preceding `all()`. So:

<pre class="python"><code>from .models import Project

def my_view(request):
    project_count = Project.objects.count()
    return render(request, '<i>name-of-some-template.html</i>', {'count': project_count})</code></pre>

Or filter objects based on a given codition like so:

<pre class="python"><code>from .models import Project

def my_view(request):
    projects = Project.objects.filter(user=request.user)
    return render(request, '<i>name-of-some-template.html</i>', {'projects': projects})</code></pre>
 
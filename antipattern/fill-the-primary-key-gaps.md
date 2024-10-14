% Fill the primary key gaps
---
severity: 3
type: antipattern
typefa: "fas fa-ban"
tags: [url, path, primary-key]
layers: models, urls, views
related_packages: []
solinks: []
---

A frequently asked question is how to "*fill the gaps*" in the primary key range. Indeed, if you have for example a model `Article` with an `AutoField`, and you create a few articles, these will have primary keys like `1`, `2`, `3`, `4`, and `5`. If we then for example remove an `Article` with primary key `2`, then if we add a new `Article`, it will not "fill the gap" and thus create a new `Article` with primary key `2`, but it will make an `Article` with primary key `6`.

It is understandable that people want to automatically reassign the primary keys of records that have been reassigned. Strictly speaking a database could easily do that, and since the database does not do that, we could run a query to automatically look for the "first" gap. Indeed, we can find the primary key we want with:

```python
# do not use this

from django.db.models import Exists, F, OuterRef

next_pk = Article.objects.filter(~Exists(Article.objects.filter(pk=OuterRef('pk')+1))).order_by('pk').values_list(F('pk')+1, flat=True).first() or 1
```

Here we thus look for an `Article` with a certain primary key, for which no primery key with the next value exists. If we find such `Article`, we thus return the next primary key. We can assign that value then as the primary key, we even could wrap this in a function and thus use this as default. But it is *not* a good idea.

# Why is it a problem?

First of all, our function will only work when there are no race conditions: it is possible that there are two processes that simultaneously try to create an `Article`, and could end up with the same primary key. We could wrap these in transactions, slowing down the process. But this problem is indeed more of a technical detail: perhaps it is possible to resolve this.

But a more severe problem is that now the URL `/article/2` no longer points to the *old* article, but to a new article. People that thus bookmarked the path `/article/2` expect to see that old article, but see the new one. Search engines could still store references to the old article, but people that click on the link now see a new article. *Tim Berners-Lee* write a document in 1998 named [*Cool URIs don't change*](https://www.w3.org/Provider/Style/URI.html) explaining that changing the location of an article is not a good idea, most arguments also hold for reassigning the URL to new data.

But the most severe problem is that there can still be a lot of items referring to the old article, that now perhaps refer to the new article. Indeed, imagine that you have a [**`GenericForeignKey`**&nbsp;<sup>\[Django-doc\]</sup>](https://docs.djangoproject.com/en/stable/ref/contrib/contenttypes/#django.contrib.contenttypes.fields.GenericForeignKey), if there is no [**`GenericRelation`**&nbsp;<sup>\[Django-doc\]</sup>](https://docs.djangoproject.com/en/stable/ref/contrib/contenttypes/#django.contrib.contenttypes.fields.GenericRelation), it will *not* be triggered to remove the objects. Indeed, imagine that we have a `Tag` model with:

```python3
class TaggedItem(models.Model):
    tag = models.SlugField()
    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE)
    object_id = models.PositiveIntegerField()
    content_object = GenericForeignKey("content_type", "object_id")
```

Now if a `TaggedItem` refers to an `Article`, and that the `Article` with primary key is `2` is removed, then the table for the `TaggedItem` will still have a record with the `content_type` for the `Article` *and* the `object_id` that points to `2`. This means that if a new article is created, then the old tags will thus now point to the new article, and therefore "inherit" the tags of the old article. This can be a severe security issue in case we have models that regulate permissions, and thus use a `GenericForeignKey`.

But the problem is not only with `GenericForeignKey`s: it is not very rare that there are tables with "weak links" to other tables, and thus still refer to the old article. Perhaps these tables are not even known to Django because these are for example provided by a different system or program. This thus can result in a *severe* security issue, but also corrupt data, and making all sorts of views and aggregates buggy.

# What can be done to resolve the problem?

Don't try to fill the gaps, generate a new primary key that does not collide with *removed* objects. Just let the database do its work. As discussed, there are good reasons why (most) databases use a strategy that does not fill the gaps. While it may not look very elegant, it is likely a lot better than trying to fill the gaps.

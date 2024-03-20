% non-atomic `JSONField`s
---
severity: 4
type: antipattern
typefa: "fas fa-ban"
tags: [orm, models, database]
layers: models
related_packages: []
solinks: ["https://stackoverflow.com/questions/58965393/query-django-jsonfields-that-are-a-list-of-dictionaries/"]
---

Several databases introduced a JSON field in the last years. This allows storing JSON blobs efficiently, and also to some extent filtering, aggregating and updating JSON blobs. Django also introduced a [**`JSONField`**&nbsp;<sup>\[Django-doc\]</sup>](https://docs.djangoproject.com/en/stable/ref/models/fields/#django.db.models.JSONField), which will use such JSON field the database provides, if it is available. However it is counter-intuitive to *relational* databases, and often still is not done very effectively.

# Why is it a problem?

First of all, it is not said that the database itself has a JSON field, for example MySQL introduced JSON fields in version 5.7.8. For databases older than this Django will have to fall back on a `CharField`, or `BinaryField` to store data as JSON. This means it is of course still possible to store JSON, but all sorts of filtering, aggregating, etc. now are not available, or at least not at the database side. The JSON will then also be stored just as a sequence of characters, which is often not the most effective way to store JSON anyway.

But a more severe problem is that it *often*, not always, but *often* violates [*first normal form (1NF)*&bnsp;<sup>\[wiki\]</sup>](https://en.wikipedia.org/wiki/First_normal_form) in database normalization. Indeed, the idea of database normalization is that you should define columns and rows in such way that you never query on a *part* of a column where you filter, aggregate, update and select: one should try to maximize filtering on the *entire* value of the column, since then the column can easily be indexed. If you want to update some part of the database, you thus rewrite these columns entirely. If we have a column with a large blob, and we only want to change one value, then writing a new blob to that column is not efficient: perhaps we have to only change a few characters. Filtering also is a problem if we want to do that on the subset of a field: unless some special indexing is in place, it would mean that we thus would have to check each row, determine that specific value for example in the JSON blob, and then check if it holds for the row. This means we have to fall back to *linear search*, which typically is *not* a good idea since as the database grows, search becomes less efficient.

Querying JSON fields also comes with a new array of tools to do that, like the `->` operator in PostgreSQL to look into JSON blobs. While Django has lookups to work with these operators, it is extra syntax and since the "vanilla SQL" syntax is already a challenge to represent this in Django, using the extra operators for JSON is even more challenging.

A final reason not to use JSON blobs is that validation of the structure of JSON is harder, especially *referential integrity*, but other parts of the structure as well. A JSON field can store anything that is JSON serializable. This thus means that if we for example expect a list of dictionaries, the database will *not* check if that is indeed the case. Validators may help, but these will run when you use forms or serializers, or actively run the validators, not when you use the models directly, and definitely not when you update items in bulk.

# What can be done to resolve the problem?

If the field has a certain structure, convert that structure into models, and *linearize* data. Indeed, imagine that we have a model with:

```
from django.conf import settings
from django.db import models


class Order(models.Model):
    customer = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT)
    lines = models.JSONField()
```

where `lines` for example look like:

```
[
    {"product_id": 14, "qty": 25},
    {"product_id": 13, "qty": 2}
]
```

we can convert this to an extra model that has a `ForeignKey` to a `Product` and where we store the quantity, like:


```
class Order(models.Model):
    customer = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT)


class OrderLine(models.Model):
    order = models.ForeignKey(Order, on_delete=models.PROTECT, related_name='lines')
    product = models.ForeignKey(Product, on_delete=models.PROTECT)
    qty = models.PositiveIntegerField()
```

here we can efficiently filter for orders with a `product_id=14` in it with:

```
Order.objects.filter(lines__product_id=14)
```

but it also ensures that each line *has* a `product_id` that refers to a valid product, that it has `qty` which is a (positive) integer, and thus that the order lines make sense. With the previous solution, it would mean less efficient searching, but it is also not said that the order lines are structured accordingly. For example we can just write `{"comment": "muhahahaha"}` to the JSON blob, which makes the `Order` invalid.

Only if the field has no *fixed* structure, or you see the JSON blob as an *atomic* value (we don't look for a specific key-value pair, or element when filtering, aggregating, updating), using a JSON blob is a good idea. If the structure is not fixed, it becomes indeed more complicated to translate this into models, and then using a `JSONField` might be appropriate, but still it is possible that this turns out to be a bottleneck.

# Extra tips

Most of what has been said in this article is not only applicable to JSON fields, but also to array fields and other fields that introduce a composite of data. While an array field is not *inherently* bad, from the moment you start filtering on *elements* of the array, and you thus treat elements of the array *individually*, problems start to arise.

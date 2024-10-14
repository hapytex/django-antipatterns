% Dictionary lookups for the database
---
type: pattern
typefa: "fas fa-shapes"
tags: [sql, case, when]
layers: [database, orm]
related_packages: []
solinks: []
---

It happens occasionally we want to perform a lookup with a dictionary for model records. Indeed, imagine we have a dictionary:

```python
prices = {
    13: 2.0,
    14: 25.0,
}
```

and we have a model `Product` that has an id and that id then determines the prices.

# What problems are solved with this?

In an ideal scenario, we store the prices in the database, for example with as an extra column, or with a separate model with a `ForeignKey` or `OneToOneField`. This will not only make the lookup a lot easier, it will also perform the JOIN more efficient: JOINs are well-researched to be done as efficient as possible, both with respect to the CPU cycles, as well as memory and disk I/O. So if you have a dictionary of data in memory, it might be better to first store it in a table and then make the JOIN.

In a seldom scenario, it might however not be possible, for example because there is no such table, or because we are not allowed to make modifications to the database, or because we want to calculate a price changes, without storing the prices. In that case we thus want to work with a dictionary lookup. The following will however *not* work:

```python
# will *not* work
Product.objects.annotate(price=prices.get(F('pk')))
```

That makes sense because `prices` is just an ordinary dictionary, and if we make a lookup with an `F` object, it will simply see there is nothing equivalent to the `F` object in the dictionary, so return `None`, and therefore all annotations will be `None`.

# What does this pattern look like?

We can work with a [**`Case`-`When`** expression&nbsp;<sup>\[Django-doc\]</sup>](https://docs.djangoproject.com/en/stable/ref/models/conditional-expressions/#case), this will for each key-value pair make a `WHEN` clause, like:

<pre class="python">from django.db.models import Case, Value, When

Product.objects.annotate(
    prices=<b>Case(*[When(pk=k, then=Value(v)) for k, v in prices.items()])</b>
)</code></pre>

This will thus make a query that looks like:

```sql
SELECT id,
    CASE
        WHEN id=13 THEN 2.0
        WHEN id=14 THEN 25.0
    END as price
FROM product
```

This is however *not* efficient: likely the database will enumerate over each case, so it will boil down to *linear search* making the query computationally expensive. This pattern thus is a solution for a *bad* problem: ideally, we try to prevent the problem from happening.

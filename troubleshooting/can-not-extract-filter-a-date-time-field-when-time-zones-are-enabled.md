% Can not extract/filter a `Date(Time)Field` when time zones are enabled
---
type: troubleshooting
typefa: "fas fa-bug"
tags: []
layers: [database, orm]
---
When using MySQL and we set the [**`USE_TZ`** setting [Django-doc]](https://docs.djangoproject.com/en/dev/ref/settings/#std:setting-USE_TZ) to `True`,
it can happen that certain (date)time-related queries no longer work.

# What are the *symptoms*?

 - If we [**<code>.filter(&hellip;)</code>** [Django-doc]](https://docs.djangoproject.com/en/dev/ref/models/querysets/#filter) with an lookup of
   a `DateField` or `DateTimeField`, we retrieve an *empty* `QuerySet`, even
   though it should normally match some records. For example `MyModel.objects.filter(created__date='1958-3-25')` returns an empty `QuerySet`.
 - If we [**<code>.annotate(&hellip;)</code>** [Django-doc]](https://docs.djangoproject.com/en/dev/ref/models/querysets/#annotate),
   then the annotated fields are `NULL` (`None`), for example if we use
   `MyModel.objects.annotate(foo=ExtractMinute('created'))`, then the
   `.foo`s of the retrieved objects are `None`.

# What is a *possible* fix?

This often means that the MySQL database has not enough information about the
time zones to do the extraction. Normally it stores data about time zones in the
`time_zone`, `time_zone_name`, `time_zone_transition` and
`time_zone_transition_table` of the `mysql` database, a database that is used to
alter the settings of the database manager.

MySQL often comes with a script that can generate the SQL queries necessary
based on the timezone files. Often these files are stored in the
`/usr/share/zoneinfo` directory, so we can generate the queries with:

```bash
time_zone_transition /usr/share/zoneinfo
```

This of course does not changes the database itself. The queries need to be
performed on the `mysql` database. We can do this manually or make use of a
pipe and work with:

<pre class="bash"><code>time_zone_transition /usr/share/zoneinfo | mysql -u <i>root</i> -p mysql</code></pre>

By entering the password of the *`root`* user (or another user that can alter
the `mysql` database), we thus can update the tables to work with the (new) time zones.

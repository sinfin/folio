# Sitemaps

Folio ships with helpers for generating XML sitemaps via the [`sitemap_generator`](https://github.com/kjvarga/sitemap_generator) gem.

- Configure your sitemap in `config/sitemap.rb`. See `test/dummy/config/sitemap.rb` for a working example.
- Use the `Folio::Sitemap` concern on models (`Page`, `File::Image`, …) to expose image data.
- Generated sitemap files are uploaded to S3 and served by `Folio::SitemapsController` from `/sitemaps/:id.xml.gz`.

Run `rake sitemap:refresh` to build the files. Make sure environment variables `S3_REGION` and `S3_BUCKET_NAME` are set.

---

[← Back to Overview](overview.md)

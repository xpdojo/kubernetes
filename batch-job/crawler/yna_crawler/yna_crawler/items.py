# -*- coding: utf-8 -*-

# Define here the models for your scraped items
#
# See documentation in:
# https://doc.scrapy.org/en/latest/topics/items.html

import scrapy


class YnaCrawlerItem(scrapy.Item):
  # define the fields for your item here like:
  # name = scrapy.Field()
  # pass

  title = scrapy.Field()
  content = scrapy.Field()
  url = scrapy.Field()
  news_category = scrapy.Field()
  article_date = scrapy.Field()
  crawled_date = scrapy.Field()

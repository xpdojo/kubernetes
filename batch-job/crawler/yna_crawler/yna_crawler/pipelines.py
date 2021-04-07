# -*- coding: utf-8 -*-

# Define your item pipelines here
#
# Don't forget to add your pipeline to the ITEM_PIPELINES setting
# See: https://doc.scrapy.org/en/latest/topics/item-pipeline.html

import datetime
from elasticsearch import Elasticsearch
from elasticsearch.client.ingest import IngestClient
from scrapy.utils.project import get_project_settings
from konlpy.tag import Okt
import logging


class YnaCrawlerPipeline(object):
  def __init__(self):
    self.settings = get_project_settings()
    self.uri = "%s://%s:%d" % (self.settings['ELASTICSEARCH_PROTOCOL'],
                               self.settings['ELASTICSEARCH_HOST'],
                               self.settings['ELASTICSEARCH_PORT'])
    self.es = Elasticsearch(self.uri, http_auth=(self.settings['ELASTICSEARCH_USERNAME'],
                                                 self.settings['ELASTICSEARCH_PASSWORD']))

  def process_item(self, item, _spider):
    index_name = 'yna_news_total_' + datetime.datetime.now().strftime('%Y%m')

    doc = dict(item)

    if not self.es.indices.exists(index=index_name):
      self.es.indices.create(index=index_name)

    client = IngestClient(self.es)
    settings = {
        "description": "Adds a field to a document with the time of ingestion",
        "processors": [
            {
                "set": {
                    "field": "@timestamp",
                    "value": "{{_ingest.timestamp}}"
                }
            }
        ]
    }
    client.put_pipeline(id='timestamp', body=settings)

    okt = Okt()
    words = list()

    nouns = okt.nouns(item['content'])
    words.extend(nouns)
    for noun in nouns:
      if len(noun) == 1:
        words.remove(noun)

    if len(words) == 0:
      words.append("")

    doc['analyzed_words'] = words
    logging.debug(doc)

    self.es.index(index=index_name, doc_type='string', body=doc, pipeline="timestamp")
    self.es.indices.refresh(index=index_name)

    return item

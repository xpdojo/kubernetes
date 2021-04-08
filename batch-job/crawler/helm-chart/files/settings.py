BOT_NAME = 'yna_crawler'
SPIDER_MODULES = ['yna_crawler.spiders']
ROBOTSTXT_OBEY = True
DOWNLOAD_DELAY = 0.5
CONCURRENT_REQUESTS_PER_DOMAIN = 2
ITEM_PIPELINES = {'yna_crawler.pipelines.YnaCrawlerPipeline': 300}
LOG_STDOUT = True
FEED_EXPORT_ENCODING = 'utf-8'

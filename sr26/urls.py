from django.conf.urls import patterns, include, url
from django.contrib import admin

urlpatterns = patterns('',
    url(r'^food$', 'sr26.views.food', name='food'),
    url(r'^food/(?P<pk>[0-9]+)$', 'sr26.views.food_detail', name='food_detal'),
    # url(r'^blog/', include('blog.urls')),
    url(r'^admin/', include(admin.site.urls)),
)

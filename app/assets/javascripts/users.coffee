$(document).on 'turbolinks:load', ->
  $('#subscribe-submit').click ->
    $('#subscribe-progress').modal('open')
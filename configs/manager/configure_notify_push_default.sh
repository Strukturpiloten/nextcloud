#!/bin/sh

# Check nginx endpoint
curl -sSfk "${NGINX_INTERNAL_URL}" > /dev/null
curl_rc=$?

case "${curl_rc}" in
  0)
    # Check if notify_push is already set up and working
    php occ -n notify_push:metrics > /dev/null
    php_rc=$?

    case "${php_rc}" in
      0)
        # notify_push is already set up and working, nothing to do
        exit 0
        ;;
      1)
        # Set up notify_push
        php occ -n notify_push:setup "https://${NEXTCLOUD_DOMAIN}/push" > /dev/null
        exit $?
        ;;
      *)
        # Unexpected php exit code
        exit "${php_rc}"
        ;;
    esac
    ;;
  *)
    # nginx endpoint is not reachable, cannot set up notify_push
    # This can also happen when the pod still starts and nginx has not yet been started
    exit "${curl_rc}"
    ;;
esac

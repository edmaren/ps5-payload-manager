#include <check.h>
#include <stdlib.h>
#include <string.h>
#include <curl/curl.h>

/* Test that protected endpoints reject unauthenticated requests */

static size_t discard_response(void *ptr, size_t size, size_t nmemb, void *data) {
    (void)ptr; (void)data;
    return size * nmemb;
}

static long make_request(const char *url, const char *auth_header) {
    CURL *curl = curl_easy_init();
    long http_code = 0;
    struct curl_slist *headers = NULL;
    
    if (auth_header) {
        headers = curl_slist_append(headers, auth_header);
    }
    
    curl_easy_setopt(curl, CURLOPT_URL, url);
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, discard_response);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 5L);
    
    if (curl_easy_perform(curl) == CURLE_OK) {
        curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &http_code);
    }
    
    curl_slist_free_all(headers);
    curl_easy_cleanup(curl);
    return http_code;
}

START_TEST(test_protected_endpoints_reject_unauthenticated)
{
    /* Invariant: Protected endpoints must return 401/403 without valid auth */
    const char *endpoints[] = {
        "http://localhost:8080/api/payload/load",
        "http://localhost:8080/api/config",
        "http://localhost:8080/api/files/delete"
    };
    const char *bad_auth[] = {
        NULL,                                    /* No auth header */
        "Authorization: Bearer expired.token.here",  /* Expired/invalid token */
        "Authorization: Bearer ../../etc/passwd"     /* Malformed/attack token */
    };
    
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            long code = make_request(endpoints[i], bad_auth[j]);
            /* Must reject with 401 Unauthorized or 403 Forbidden */
            ck_assert_msg(code == 401 || code == 403,
                "Endpoint %s accepted unauthenticated request (got %ld)", 
                endpoints[i], code);
        }
    }
}
END_TEST

Suite *security_suite(void)
{
    Suite *s;
    TCase *tc_core;

    s = suite_create("Security");
    tc_core = tcase_create("Core");

    tcase_add_test(tc_core, test_protected_endpoints_reject_unauthenticated);
    suite_add_tcase(s, tc_core);

    return s;
}

int main(void)
{
    int number_failed;
    Suite *s;
    SRunner *sr;

    curl_global_init(CURL_GLOBAL_DEFAULT);
    
    s = security_suite();
    sr = srunner_create(s);

    srunner_run_all(sr, CK_NORMAL);
    number_failed = srunner_ntests_failed(sr);
    srunner_free(sr);

    curl_global_cleanup();
    return (number_failed == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}
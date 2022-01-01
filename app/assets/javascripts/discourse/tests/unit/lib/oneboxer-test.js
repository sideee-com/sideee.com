import { failedCache, localCache } from "pretty-text/oneboxer-cache";
import { module, test } from "qunit";
import { ajax } from "discourse/lib/ajax";
import { load } from "pretty-text/oneboxer";

function loadOnebox(element) {
  return load({
    elem: element,
    refresh: false,
    ajax,
    synchronous: true,
    categoryId: 1,
    topicId: 1,
  });
}

module("Unit | Utility | oneboxer", function () {
  test("load - failed onebox", async function (assert) {
    let element = document.createElement("A");
    element.setAttribute("href", "http://somebadurl.com");

    await loadOnebox(element);

    assert.strictEqual(
      failedCache["http://somebadurl.com"],
      true,
      "stores the url as failed in a cache"
    );
    assert.strictEqual(
      loadOnebox(element),
      undefined,
      "it returns early for a failed cache"
    );
  });

  test("load - successful onebox", async function (assert) {
    let element = document.createElement("A");
    element.setAttribute("href", "http://somegoodurl.com");

    await loadOnebox(element);

    assert.ok(
      localCache["http://somegoodurl.com"].outerHTML.indexOf(
        "Yet another collaboration tool"
      ) !== -1,
      "stores the html of the onebox in a local cache"
    );
    assert.ok(
      loadOnebox(element).indexOf("Yet another collaboration tool") !== -1,
      "it returns the html from the cache"
    );
  });
});

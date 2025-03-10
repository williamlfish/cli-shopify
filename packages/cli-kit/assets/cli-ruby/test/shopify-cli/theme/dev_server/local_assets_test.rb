# frozen_string_literal: true

require "test_helper"
require "shopify_cli/theme/dev_server"
require "rack/mock"

module ShopifyCLI
  module Theme
    class DevServer
      class LocalAssetsTest < Minitest::Test
        def setup
          super
          Environment.stubs(:store).returns("my-test-shop.myshopify.com")
        end

        def test_replace_local_assets_in_reponse_body
          original_html = <<~HTML
            <html>
              <head>
                <link rel="stylesheet" href="//cdn.shopify.com/s/files/1/0457/3256/0918/t/2/assets/theme.css?enable_css_minification=1&v=3271603065762738033" />
              </head>
            </html>
          HTML
          expected_html = <<~HTML
            <html>
              <head>
                <link rel="stylesheet" href="/assets/theme.css?enable_css_minification=1&v=3271603065762738033" />
              </head>
            </html>
          HTML
          assert_equal(expected_html, serve(original_html).body)
        end

        def test_replace_local_assets_on_same_line
          original_html = <<~HTML
            <html>
              <head>
                <link rel="stylesheet" href="//cdn.shopify.com/s/files/1/0457/3256/0918/t/2/assets/theme.css?enable_css_minification=1&v=3271603065762738033" /><link rel="stylesheet" href="//cdn.shopify.com/s/files/1/0457/3256/0918/t/2/assets/theme.css?enable_css_minification=1&v=3271603065762738033" />
              </head>
            </html>
          HTML
          expected_html = <<~HTML
            <html>
              <head>
                <link rel="stylesheet" href="/assets/theme.css?enable_css_minification=1&v=3271603065762738033" /><link rel="stylesheet" href="/assets/theme.css?enable_css_minification=1&v=3271603065762738033" />
              </head>
            </html>
          HTML
          assert_equal(expected_html, serve(original_html).body)
        end

        def test_replace_local_assets_in_reponse_body_with_vanity_url
          original_html = <<~HTML
            <html>
              <head>
                <link rel="stylesheet" href="/cdn/shop/t/2/assets/theme.css" />
              </head>
            </html>
          HTML
          expected_html = <<~HTML
            <html>
              <head>
                <link rel="stylesheet" href="/assets/theme.css" />
              </head>
            </html>
          HTML
          assert_equal(expected_html, serve(original_html).body)
        end

        def test_dont_replace_other_assets
          original_html = <<~HTML
            <html>
              <head>
                <script src="https://cdn.shopify.com/s/trekkie.storefront.9f320156b58d74db598714aa83b6a5fbab4d4efb.min.js"></script>
              </head>
            </html>
          HTML
          assert_equal(original_html, serve(original_html).body)
        end

        def test_serve_css_from_disk
          response = serve("<WRONG>", path: "/assets/theme.css")
          assert_equal("text/css", response["Content-Type"])
          assert_equal(
            ::File.read("#{ShopifyCLI::ROOT}/test/fixtures/theme/assets/theme.css"),
            response.body,
          )
        end

        def test_serve_js_from_disk
          response = serve("<WRONG>", path: "/assets/theme.js")
          assert_equal("application/javascript", response["Content-Type"])
          assert_equal(
            ::File.read("#{ShopifyCLI::ROOT}/test/fixtures/theme/assets/theme.css"),
            response.body,
          )
        end

        def test_serve_file_with_a_not_theme_file
          response = serve("<WRONG>", path: "/assets/../../../test_helper.rb")
          assert_equal("text/plain", response["Content-Type"])
          assert_equal("Not found", response.body)
        end

        def test_serve_file_with_a_non_static_asset
          response = serve("<WRONG>", path: "/assets/../config/super_secret.json")
          assert_equal("text/plain", response["Content-Type"])
          assert_equal("Not found", response.body)
        end

        def test_404_on_missing_local_assets
          response = serve("<WRONG>", path: "/assets/missing.css")
          assert_equal("text/plain", response["Content-Type"])
          assert_equal("Not found", response.body)
        end

        def test_replace_local_images_in_reponse_body
          theme = stub("Theme", static_asset_paths: [
            "assets/test-image.png",
            "assets/test-image.png",
            "assets/test-image.jpeg",
            "assets/test-image.jpg",
            "assets/test-vector.svg",
            "assets/folha_de_estilo.css",
            "assets/script.js",
            "assets/static_object.json",
          ])

          original_html = <<~HTML
            <html>
              <body>
                <div data-src="//cdn.shopify.com/s/files/1/0000/1111/2222/t/333/assets/test-image.png?v=111111111111"></div>
                <div data-src="//cdn.shopify.com/s/files/1/0000/1111/2222/t/333/assets/test-image.jpeg?v=111111111111"></div>
                <div data-src="//cdn.shopify.com/s/files/1/0000/1111/2222/t/333/assets/test-image.jpg?v=111111111111"></div>
                <div data-src="//cdn.shopify.com/s/files/1/0000/1111/2222/t/333/assets/test-vector.svg?v=111111111111"></div>
                <div data-src="//cdn.shopify.com/s/files/1/0000/1111/2222/t/333/assets/folha_de_estilo.css?v=111111111111"></div>
                <div data-src="//cdn.shopify.com/s/files/1/0000/1111/2222/t/333/assets/script.js?v=111111111111"></div>
              </body>
            </html>
          HTML
          expected_html = <<~HTML
            <html>
              <body>
                <div data-src="/assets/test-image.png?v=111111111111"></div>
                <div data-src="/assets/test-image.jpeg?v=111111111111"></div>
                <div data-src="/assets/test-image.jpg?v=111111111111"></div>
                <div data-src="/assets/test-vector.svg?v=111111111111"></div>
                <div data-src="/assets/folha_de_estilo.css?v=111111111111"></div>
                <div data-src="/assets/script.js?v=111111111111"></div>
              </body>
            </html>
          HTML

          assert_equal(expected_html, serve(original_html, theme_mock: theme).body)
        end

        def test_replace_shop_assets_urls_in_reponse_body
          theme = stub("Theme", static_asset_paths: [
            "assets/component-list-menu.css",
          ])

          original_html = <<~HTML
            <html>
              <head>
              <link rel="stylesheet" href="//my-test-shop.myshopify.com/assets/component-list-menu.css?v=11111" media="print" onload="this.media='all'">
              <link rel="stylesheet" href="http://my-test-shop.myshopify.com/assets/component-list-menu.css?v=11111" media="print" onload="this.media='all'">
              <link rel="stylesheet" href="https://my-test-shop.myshopify.com/assets/component-list-menu.css?v=11111" media="print" onload="this.media='all'">
              </head>
            </html>
          HTML

          expected_html = <<~HTML
            <html>
              <head>
              <link rel="stylesheet" href="/assets/component-list-menu.css?v=11111" media="print" onload="this.media='all'">
              <link rel="stylesheet" href="/assets/component-list-menu.css?v=11111" media="print" onload="this.media='all'">
              <link rel="stylesheet" href="/assets/component-list-menu.css?v=11111" media="print" onload="this.media='all'">
              </head>
            </html>
          HTML

          assert_equal(expected_html, serve(original_html, theme_mock: theme).body)
        end

        private

        def serve(response_body, path: "/", theme_mock: nil)
          app = lambda do |_env|
            [200, {}, [response_body]]
          end
          root = ShopifyCLI::ROOT + "/test/fixtures/theme"
          ctx = TestHelpers::FakeContext.new(root: root)
          theme = theme_mock || Theme.new(ctx, root: root)
          stack = LocalAssets.new(ctx, app, theme)
          request = Rack::MockRequest.new(stack)
          request.get(path)
        end
      end
    end
  end
end

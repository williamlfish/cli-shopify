# frozen_string_literal: true

require "test_helper"
require "shopify_cli/theme/extension/dev_server"
require "rack/mock"

module ShopifyCLI
  module Theme
    module Extension
      class DevServer
        class LocalAssetsTest < Minitest::Test
          def test_replace_local_assets_in_reponse_body_https
            original_html = <<~HTML
              <html>
                <head>
                  <link rel="stylesheet" href="https://cdn.shopify.com/extensions/some-alphanumeric-id/0.0.0/assets/block1.css?v=1657160440" />
                </head>
              </html>
            HTML
            expected_html = <<~HTML
              <html>
                <head>
                  <link rel="stylesheet" href="/assets/block1.css?v=1657160440" />
                </head>
              </html>
            HTML
            assert_equal(expected_html, serve(original_html).body)
          end

          def test_replace_local_assets_in_reponse_body_http
            original_html = <<~HTML
              <html>
                <head>
                  <link rel="stylesheet" href="http://cdn.shopify.com/extensions/some-alphanumeric-id/0.0.0/assets/block1.css?v=1657160440" />
                </head>
              </html>
            HTML
            expected_html = <<~HTML
              <html>
                <head>
                  <link rel="stylesheet" href="/assets/block1.css?v=1657160440" />
                </head>
              </html>
            HTML
            assert_equal(expected_html, serve(original_html).body)
          end

          def test_replace_local_assets_on_same_line
            original_html = <<~HTML
              <html>
                <head>
                  <link rel="stylesheet" href="https://cdn.shopify.com/extensions/some-alphanumeric-id/0.0.0/assets/block1.css?v=1657160440" /><link rel="stylesheet" href="https://cdn.shopify.com/extensions/some-alphanumeric-id/0.0.0/assets/block1.css?v=1657160440" />
                </head>
              </html>
            HTML
            expected_html = <<~HTML
              <html>
                <head>
                  <link rel="stylesheet" href="/assets/block1.css?v=1657160440" /><link rel="stylesheet" href="/assets/block1.css?v=1657160440" />
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
            response = serve("<WRONG>", path: "/assets/block1.css")
            assert_equal("text/css", response["Content-Type"])
            assert_equal(
              ::File.read("#{ShopifyCLI::ROOT}/test/fixtures/extension/assets/block1.css"),
              response.body,
            )
          end

          def test_serve_js_from_disk
            response = serve("<WRONG>", path: "/assets/block1.js")
            assert_equal("application/javascript", response["Content-Type"])
            assert_equal(
              ::File.read("#{ShopifyCLI::ROOT}/test/fixtures/extension/assets/block1.css"),
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
            extension = stub("Extension", static_asset_paths: [
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
                  <div data-src="//cdn.shopify.com/extensions/s/files/1/0000/1111/2222/t/333/assets/test-image.png?v=111111111111"></div>
                  <div data-src="//cdn.shopify.com/extensions/s/files/1/0000/1111/2222/t/333/assets/test-image.jpeg?v=111111111111"></div>
                  <div data-src="//cdn.shopify.com/extensions/s/files/1/0000/1111/2222/t/333/assets/test-image.jpg?v=111111111111"></div>
                  <div data-src="//cdn.shopify.com/extensions/s/files/1/0000/1111/2222/t/333/assets/test-vector.svg?v=111111111111"></div>
                  <div data-src="//cdn.shopify.com/extensions/s/files/1/0000/1111/2222/t/333/assets/folha_de_estilo.css?v=111111111111"></div>
                  <div data-src="//cdn.shopify.com/extensions/s/files/1/0000/1111/2222/t/333/assets/script.js?v=111111111111"></div>
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

            assert_equal(expected_html, serve(original_html, extension_mock: extension).body)
          end

          private

          def serve(response_body, path: "/", extension_mock: nil)
            app = lambda do |_env|
              [200, {}, [response_body]]
            end
            root = ShopifyCLI::ROOT + "/test/fixtures/extension"
            ctx = TestHelpers::FakeContext.new(root: root)
            extension = extension_mock || AppExtension.new(ctx, root: root)
            stack = LocalAssets.new(ctx, app, extension)
            request = Rack::MockRequest.new(stack)
            request.get(path)
          end
        end
      end
    end
  end
end

import {App, AppInterface} from './app.js'
import {FunctionExtension, ThemeExtension, UIExtension} from './extensions.js'
import {ExtensionTemplate} from './template.js'
import {RemoteSpecification} from '../../api/graphql/extension_specifications.js'
import themeExtension from '../templates/theme-specifications/theme.js'
import checkoutPostPurchaseExtension from '../templates/ui-specifications/checkout_post_purchase.js'
import checkoutUIExtension from '../templates/ui-specifications/checkout_ui_extension.js'
import {ExtensionInstance} from '../extensions/extension-instance.js'
import {loadLocalExtensionsSpecifications} from '../extensions/load-specifications.js'
import {FunctionConfigType} from '../extensions/specifications/function.js'
import UIExtensionTemplate from '../templates/ui-specifications/ui_extension.js'

export function testApp(app: Partial<AppInterface> = {}): AppInterface {
  const newApp = new App(
    app.name ?? 'App',
    app.idEnvironmentVariableName ?? 'SHOPIFY_API_KEY',
    app.directory ?? '/tmp/project',
    app.packageManager ?? 'yarn',
    app.configuration ?? {scopes: '', extensionDirectories: []},
    app.configurationPath ?? '/tmp/project/shopify.app.toml',
    app.nodeDependencies ?? {},
    app.webs ?? [],
    app.allExtensions ?? [],
    app.usesWorkspaces ?? false,
    app.dotenv,
    app.errors,
  )
  if (app.updateDependencies) {
    Object.getPrototypeOf(newApp).updateDependencies = app.updateDependencies
  }
  if (app.hasUIExtensions) {
    Object.getPrototypeOf(newApp).hasUIExtensions = app.hasUIExtensions
  }
  if (app.extensionsForType) {
    Object.getPrototypeOf(newApp).extensionsForType = app.extensionsForType
  }
  return newApp
}

export async function testUIExtension(uiExtension: Partial<UIExtension> = {}): Promise<ExtensionInstance> {
  const directory = uiExtension?.directory ?? '/tmp/project/extensions/test-ui-extension'

  const configuration = uiExtension?.configuration ?? {
    name: uiExtension?.configuration?.name ?? 'test-ui-extension',
    type: uiExtension?.configuration?.type ?? uiExtension?.type ?? 'product_subscription',
    metafields: [],
    capabilities: {
      block_progress: false,
      network_access: false,
      api_access: false,
    },
  }
  const configurationPath = uiExtension?.configurationPath ?? `${directory}/shopify.ui.extension.toml`
  const entryPath = uiExtension?.entrySourceFilePath ?? `${directory}/src/index.js`

  const allSpecs = await loadLocalExtensionsSpecifications()
  const specification = allSpecs.find((spec) => spec.identifier === configuration.type)!

  const extension = new ExtensionInstance({
    configuration,
    configurationPath,
    entryPath,
    directory,
    specification,
  })

  extension.devUUID = uiExtension?.devUUID ?? 'test-ui-extension-uuid'
  return extension
}

export async function testThemeExtensions(): Promise<ExtensionInstance & ThemeExtension> {
  const configuration = {
    name: 'theme extension name',
    type: 'theme' as const,
    metafields: [],
  }

  const allSpecs = await loadLocalExtensionsSpecifications()
  const specification = allSpecs.find((spec) => spec.identifier === 'theme')!

  const extension = new ExtensionInstance({
    configuration,
    configurationPath: '',
    directory: './my-extension',
    specification,
  })

  extension.outputBundlePath = './my-extension'

  return extension
}

function defaultFunctionConfiguration(): FunctionConfigType {
  return {
    name: 'test function extension',
    description: 'description',
    type: 'product_discounts',
    build: {
      command: 'echo "hello world"',
    },
    apiVersion: '2022-07',
    configurationUi: true,
    metafields: [],
  }
}

interface TestFunctionExtensionOptions {
  dir?: string
  config?: FunctionConfigType
  entryPath?: string
}

export async function testFunctionExtension(
  opts: TestFunctionExtensionOptions = {},
): Promise<ExtensionInstance & FunctionExtension> {
  const directory = opts.dir ?? '/tmp/project/extensions/my-function'
  const configuration = opts.config ?? defaultFunctionConfiguration()

  const allSpecs = await loadLocalExtensionsSpecifications()
  const specification = allSpecs.find((spec) => spec.identifier === 'function')!

  const extension = new ExtensionInstance({
    configuration,
    configurationPath: '',
    entryPath: opts.entryPath,
    directory,
    specification,
  })
  return extension
}

export const testRemoteSpecifications: RemoteSpecification[] = [
  {
    name: 'Checkout Post Purchase',
    externalName: 'Post-purchase UI',
    identifier: 'checkout_post_purchase',
    externalIdentifier: 'checkout_post_purchase_external',
    gated: false,
    options: {
      managementExperience: 'cli',
      registrationLimit: 1,
    },
    features: {
      argo: {
        surface: 'checkout',
      },
    },
  },
  {
    name: 'Online Store - App Theme Extension',
    externalName: 'Theme App Extension',
    identifier: 'theme',
    externalIdentifier: 'theme_external',
    gated: false,
    options: {
      managementExperience: 'cli',
      registrationLimit: 1,
    },
  },
  {
    name: 'Product Subscription',
    externalName: 'Subscription UI',
    identifier: 'product_subscription',
    externalIdentifier: 'product_subscription_external',
    gated: false,
    options: {
      managementExperience: 'cli',
      registrationLimit: 1,
    },
    features: {
      argo: {
        surface: 'admin',
      },
    },
  },
  {
    name: 'UI Extension',
    externalName: 'UI Extension',
    identifier: 'ui_extension',
    externalIdentifier: 'ui_extension_external',
    gated: false,
    options: {
      managementExperience: 'cli',
      registrationLimit: 50,
    },
    features: {
      argo: {
        surface: 'all',
      },
    },
  },
  {
    name: 'Customer Accounts',
    externalName: 'Customer Accounts',
    identifier: 'customer_accounts_ui_extension',
    externalIdentifier: 'customer_accounts_ui_extension_external',
    gated: false,
    options: {
      managementExperience: 'cli',
      registrationLimit: 10,
    },
    features: {
      argo: {
        surface: 'customer_accounts',
      },
    },
  },
  {
    name: 'Checkout Extension',
    externalName: 'Checkout UI',
    identifier: 'checkout_ui_extension',
    externalIdentifier: 'checkout_ui_extension_external',
    gated: false,
    options: {
      managementExperience: 'cli',
      registrationLimit: 5,
    },
    features: {
      argo: {
        surface: 'checkout',
      },
    },
  },
  {
    name: 'Product Subscription',
    externalName: 'Subscription UI',
    // we are going to replace this to 'product_subscription' because we
    // started using it before relying on the extension specification identifier
    identifier: 'subscription_management',
    externalIdentifier: 'product_subscription_external',
    gated: false,
    options: {
      managementExperience: 'cli',
      registrationLimit: 1,
    },
    features: {
      argo: {
        surface: 'admin',
      },
    },
  },
  {
    name: 'Marketing Activity',
    externalName: 'Marketing Activity',
    identifier: 'marketing_activity_extension',
    externalIdentifier: 'marketing_activity_extension_external',
    gated: false,
    options: {
      managementExperience: 'dashboard',
      registrationLimit: 100,
    },
  },
  {
    name: 'function',
    externalName: 'function',
    identifier: 'function',
    externalIdentifier: 'function',
    gated: false,
    options: {
      managementExperience: 'cli',
      registrationLimit: 1,
    },
    features: {
      argo: {
        surface: 'checkout',
      },
    },
  },
]

export const testRemoteExtensionTemplates: ExtensionTemplate[] = [
  {
    identifier: 'cart_checkout_validation',
    name: 'Function - Cart and Checkout Validation',
    group: 'Discounts and checkout',
    supportLinks: ['https://shopify.dev/docs/api/functions/reference/cart-checkout-validation'],
    types: [
      {
        type: 'function',
        url: 'https://github.com/Shopify/function-examples',
        extensionPoints: [],
        supportedFlavors: [
          {
            name: 'Rust',
            value: 'rust',
            path: 'checkout/rust/cart-checkout-validation/default',
          },
        ],
      },
    ],
  },
  {
    identifier: 'cart_transform',
    name: 'Function - Cart transformer',
    group: 'Discounts and checkout',
    supportLinks: [],
    types: [
      {
        type: 'function',
        url: 'https://github.com/Shopify/function-examples',
        extensionPoints: [],
        supportedFlavors: [
          {
            name: 'Wasm',
            value: 'wasm',
            path: 'checkout/wasm/cart-transform/default',
          },
          {
            name: 'Rust',
            value: 'rust',
            path: 'checkout/rust/cart-transform/default',
          },
        ],
      },
    ],
  },
  {
    identifier: 'product_discounts',
    name: 'Function - Product discounts',
    group: 'Discounts and checkout',
    supportLinks: ['https://shopify.dev/docs/apps/discounts'],
    types: [
      {
        type: 'function',
        url: 'https://github.com/Shopify/function-examples',
        extensionPoints: [],
        supportedFlavors: [
          {
            name: 'Wasm',
            value: 'wasm',
            path: 'discounts/wasm/product-discounts/default',
          },
          {
            name: 'Rust',
            value: 'rust',
            path: 'discounts/rust/product-discounts/default',
          },
        ],
      },
    ],
  },
  {
    identifier: 'order_discounts',
    name: 'Function - Order discounts',
    group: 'Discounts and checkout',
    supportLinks: [],
    types: [
      {
        type: 'function',
        url: 'https://github.com/Shopify/function-examples',
        extensionPoints: [],
        supportedFlavors: [
          {
            name: 'Wasm',
            value: 'wasm',
            path: 'discounts/wasm/order-discounts/default',
          },
          {
            name: 'Rust',
            value: 'rust',
            path: 'discounts/rust/order-discounts/default',
          },
          {
            name: 'JavaScript',
            value: 'vanilla-js',
            path: 'discounts/javascript/order-discounts/default',
          },
        ],
      },
    ],
  },
]

export const testLocalExtensionTemplates: ExtensionTemplate[] = [
  themeExtension,
  checkoutPostPurchaseExtension,
  checkoutUIExtension,
  UIExtensionTemplate,
]

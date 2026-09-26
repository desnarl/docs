import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

const config: Config = {
  title: 'Desnarl',
  tagline: 'Cross-repo impact, consumers and schema references — on your own infrastructure.',
  favicon: 'img/favicon.ico',

  future: {
    v4: true, // Improve compatibility with the upcoming Docusaurus v4
  },

  // Served at the domain root via Cloudflare Pages, not a GitHub-Pages-style
  // project subpath — baseUrl is '/', not '/docs/'.
  url: 'https://docs.desnarl.com',
  baseUrl: '/',
  trailingSlash: false,

  onBrokenLinks: 'throw',
  markdown: {
    hooks: {
      onBrokenMarkdownLinks: 'warn',
    },
  },

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          routeBasePath: '/', // this repo is nothing but docs — root doc gets `slug: /`
          editUrl: 'https://github.com/desnarl/docs/tree/main/',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    colorMode: {
      defaultMode: 'dark',
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'Desnarl',
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'docsSidebar',
          position: 'left',
          label: 'Docs',
        },
        {
          href: 'https://desnarl.com',
          label: 'desnarl.com',
          position: 'right',
        },
        {
          href: 'https://github.com/desnarl/docs',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Docs',
          items: [
            {label: 'Getting started', to: '/getting-started/install'},
            {label: 'MCP tool reference', to: '/mcp-tools/reference'},
            {label: 'Troubleshooting', to: '/troubleshooting'},
          ],
          // Paths are relative to routeBasePath ('/'), so no leading /docs/.
        },
        {
          title: 'Product',
          items: [
            {label: 'desnarl.com', href: 'https://desnarl.com'},
            {label: 'Licensing & pricing FAQ', to: '/licensing-pricing-faq'},
          ],
        },
        {
          title: 'More',
          items: [{label: 'GitHub', href: 'https://github.com/desnarl/docs'}],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Desnarl.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
    },
  } satisfies Preset.ThemeConfig,
};

export default config;

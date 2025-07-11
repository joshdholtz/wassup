/**
 * Creating a sidebar enables you to:
 - create an ordered group of docs
 - render a sidebar for each doc of that group
 - provide next/previous navigation

 The sidebars can be generated from the filesystem, or explicitly defined here.

 Create as many sidebars as you want.
 */

// @ts-check

/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  tutorialSidebar: [
    'intro',
    {
      type: 'category',
      label: 'Getting Started',
      items: [
        'basics/simple-configuration',
      ],
    },
    {
      type: 'category',
      label: 'Configuration',
      items: [
        'configuration/understanding-supfile',
        'configuration/pane-properties',
        'advanced/complex-layouts',
      ],
    },
    {
      type: 'category',
      label: 'Integrations',
      items: [
        {
          type: 'category',
          label: 'GitHub',
          items: [
            'integrations/github/setup',
            'integrations/github/helpers',
            'integrations/github/formatters',
          ],
        },
      ],
    },
    {
      type: 'category',
      label: 'Examples',
      items: [
        'examples/dashboard-layouts',
      ],
    },
    {
      type: 'category',
      label: 'Debug & Troubleshooting',
      items: [
        'debug/troubleshooting',
      ],
    },
  ],
};

module.exports = sidebars;

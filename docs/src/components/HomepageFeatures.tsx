import React from 'react';
import clsx from 'clsx';
import styles from './HomepageFeatures.module.css';

type FeatureItem = {
  title: string;
  image: string;
  description: JSX.Element;
};

const FeatureList: FeatureItem[] = [
  {
    title: 'Easy to Configure',
    image: '/img/demo-supfile.png',
    description: (
      <>
        Wassup was designed to be easy to use but with maximum flexibilty. Configure
        size, position, content, and selection of the panes in the <code>Supfile</code>.
      </>
    ),
  },
  {
    title: 'Easy to Use',
    image: '/img/wassup-screenshot.png',
    description: (
      <>
        Run `wassup` in the same directory as your <code>Supfile</code> to show the dashboard. Press the number
        keys to interact with a specific pane. Highlight rows with <code>j</code> and <code>k</code> and press <code>Enter</code> to select.
      </>
    ),
  },
];

function Feature({title, image, description}: FeatureItem) {
  return (
    <div className={clsx('col col--6')}>
      <div className="text--center">
        <img className={styles.featureSvg} alt={title} src={image} />
      </div>
      <div className="text--center padding-horiz--md">
        <h3>{title}</h3>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures(): JSX.Element {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}

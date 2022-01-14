import React from 'react';
import clsx from 'clsx';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import styles from './index.module.css';
import HomepageFeatures from '../components/HomepageFeatures';

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header className={clsx('hero hero--primary', styles.heroBanner)}>
      <div className="container">
        <div className={styles.calloutAndLogo}>
          <div className={styles.callout}>
            <h1 className={styles.title}>Wassup</h1>
            <h2 className={styles.callout}>
              Easily configure and script <br/> a personal terminal dashboard
            </h2>
          </div>
          <img className={styles.heroLogo} src="/img/wassup.png" alt="Wassup logo"/> 
        </div>
        <div className={styles.buttons}>
          <Link
            className="button button--secondary button--lg"
            to="/docs/intro">
            Getting Started - 5min ⏱️
          </Link>
        </div>
      </div>
    </header>
  );
}

function HomepageMoreInfo() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <div className={styles.moreInfo}>
      Script <strong>your own panes</strong> or use Wassup's <strong>built-in panes</strong>!
    </div>
  );
}

export default function Home(): JSX.Element {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title={`Hello from ${siteConfig.title}`}
      description="Description will go into a meta tag in <head />">
      <HomepageHeader />
      <HomepageMoreInfo />
      <main>
        <HomepageFeatures />
      </main>
    </Layout>
  );
}

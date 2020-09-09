/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 * @flow strict-local
 */

import React from 'react';
import {
  NativeEventEmitter,
  NativeModules,
  SafeAreaView,
  StyleSheet,
  ScrollView,
  View,
  Text,
  StatusBar,
  Button,
  Alert,
} from 'react-native';

import {
  Header,
  LearnMoreLinks,
  Colors,
  DebugInstructions,
  ReloadInstructions,
} from 'react-native/Libraries/NewAppScreen';

import * as Progress from 'react-native-progress';

class App extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      isStarted: false,
      isDownloading: false,
      latestHeight: 'awaiting start...',
      totalBalance: '0',
      statusMessage: '',
      status: '',
      progress: 0,
    };
  }

  handleClick = () => {
    NativeModules.ZcashReactSdk.start();
    this.setState({isStarted: true, latestHeight: 'syncing...'});
  };

  componentDidMount() {
    NativeModules.ZcashReactSdk.initialize(
      'zxviews1qw28psv0qqqqpqr2ru0kss5equx6h0xjsuk5299xrsgdqnhe0cknkl8uqff34prwkysswfhjk79n8l99f2grd26dqg6dy3jcmxsaypxfsu6ara6vsk3x8l544uaksstx9zre879mdg7s9a7zurrx6pf5qg2n323js2s3zlu8tn3848yyvlg4w38gx75cyv9jdpve77x9eq6rtl6d9qyh8det4edevlnc70tg5kse670x50764gzhy60dta0yv3wsd4fsuaz686lgszcq7kwxy',
      921100,
    )
      .then((response) => this.setState({status: 'initialized'}))
      .catch((error) =>
        NativeModules.ZcashReactSdk.show('Warning: Already initialized.'),
      );

    const eventEmitter = new NativeEventEmitter(NativeModules.ZcashReactSdk);
    this.updateListener = eventEmitter.addListener('UpdateEvent', (event) => {
      let message;
      if (event.isDownloading) {
        message = `Downloading block ${event.lastDownloadedHeight}`;
      } else if (event.isScanning) {
        message = `Scanning block ${event.lastScannedHeight}`;
      } else {
        if (this.state.totalBalance === '0') {
          message = 'balance: refreshing...';
        } else {
          message = `balance: ${this.state.totalBalance} ZEC`;
        }
      }

      this.setState({
        statusMessage: `${message}\n\n`,
        progress: event.scanProgress,
        isDownloading: event.isDownloading,
        latestHeight:
          event.networkBlockHeight > 0
            ? event.networkBlockHeight
            : 'loading...',
      });
    });
    this.statusListener = eventEmitter.addListener('StatusEvent', (event) => {
      this.setState({status: event.name});
    });
    this.balanceListener = eventEmitter.addListener('BalanceEvent', (event) => {
      this.setState({totalBalance: event.total});
    });
  }

  componentWillUnmount() {
    this.updateListener.remove();
    this.statusListener.remove();
    this.balanceListener.remove();
  }
  render() {
    return (
      <>
        <StatusBar barStyle="dark-content" />
        <SafeAreaView>
          <ScrollView
            contentInsetAdjustmentBehavior="automatic"
            style={styles.scrollView}>
            <Header />
            {global.HermesInternal == null ? null : (
              <View style={styles.engine}>
                <Text style={styles.footer}>Engine: Hermes</Text>
              </View>
            )}
            <View style={styles.body}>
              <View style={styles.sectionContainer}>
                <Text style={styles.sectionTitle}>Latest Height</Text>
                <Text style={styles.sectionDescription}>
                  {this.state.latestHeight}
                </Text>
              </View>
              <View style={styles.sectionContainer}>
                <Text style={styles.sectionTitle}>
                  Status: {this.state.status}
                </Text>
                <Text style={styles.sectionDescription}>
                  {this.state.statusMessage}
                </Text>
                <View style={styles.progressView}>
                  {this.state.isStarted && (
                    <Progress.Circle
                      size={100}
                      showsText={true}
                      indeterminate={this.state.isDownloading}
                      progress={this.state.progress / 100.0}
                    />
                  )}
                </View>
                {!this.state.isStarted && (
                  <Button title="start" onPress={this.handleClick} />
                )}
              </View>
            </View>
          </ScrollView>
        </SafeAreaView>
      </>
    );
  }
}

const styles = StyleSheet.create({
  scrollView: {
    backgroundColor: Colors.lighter,
  },
  engine: {
    position: 'absolute',
    right: 0,
  },
  body: {
    backgroundColor: Colors.white,
  },
  sectionContainer: {
    marginTop: 32,
    paddingHorizontal: 24,
  },
  sectionTitle: {
    fontSize: 24,
    fontWeight: '600',
    color: Colors.black,
  },
  sectionDescription: {
    marginTop: 8,
    fontSize: 18,
    fontWeight: '400',
    color: Colors.dark,
  },
  highlight: {
    fontWeight: '700',
  },
  footer: {
    color: Colors.dark,
    fontSize: 12,
    fontWeight: '600',
    padding: 4,
    paddingRight: 12,
    textAlign: 'right',
  },
  progressView: {
    paddingBottom: 20,
    justifyContent: 'center',
    alignItems: 'center',
  },
});

export default App;

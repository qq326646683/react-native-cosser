import {Platform} from 'react-native';

const CosSerModule = require('react-native').NativeModules.CosSerModule;
const RNHyphenate = require('react-native').NativeModules.RNHyphenate;


if (Platform.OS === 'android') {
  module.exports = CosSerModule
} else {
  module.exports = {
    ...RNHyphenate,
    setInfo: function (info) {
      return RNHyphenate.setInfo(info)
    }
  }
}





module.exports = {
  parser: '@babel/eslint-parser',
  parserOptions: {
    ecmaVersion: 2020,
    ecmaFeatures: {
      impliedStrict: true,
      classes: true
    }
  },
  env: {
    browser: true,
    node: true
  },
  extends: [
    'airbnb',
    'airbnb/hooks',
    'plugin:@next/next/recommended',
    'plugin:prettier/recommended'
  ],
  rules: {
    'import/extensions': 'off',
    'import/no-unresolved': [
      'error',
      {
        ignore: ['~/']
      }
    ],
    'react/prop-types': 'off',
    'react/react-in-jsx-scope': 'off'
  }
}

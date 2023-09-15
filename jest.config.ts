/**
 * For a detailed explanation regarding each configuration property, visit:
 * https://jestjs.io/docs/configuration
 */

import type {Config} from 'jest';

const config: Config = {
   preset: 'ts-jest/presets/js-with-ts-esm',
   rootDir: "test",
   testMatch: [
      "**/?(*.)+(test).[tj]s"
   ],
   transform: {},
   extensionsToTreatAsEsm: ['.ts'],
};

export default config;

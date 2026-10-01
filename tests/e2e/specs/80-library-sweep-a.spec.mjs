// Library sweep part a: every program in this slice of RC.LIBRARY opens, runs ~400 ms with keys typed, no errors.
import { registerSweep } from './80-library-sweep.lib.mjs';
export default (t) => registerSweep(t, 0);

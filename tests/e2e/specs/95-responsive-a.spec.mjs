// Responsive layout matrix, phones and tablets in portrait (first half of the viewport list).
import { matrix, VIEWPORTS } from './95-responsive-matrix.mjs';
export default (t) => matrix(t, VIEWPORTS.slice(0, 8));

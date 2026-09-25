// Responsive layout matrix, tablets in landscape and desktops (second half of the viewport list).
import { matrix, VIEWPORTS } from './95-responsive-matrix.mjs';
export default (t) => matrix(t, VIEWPORTS.slice(8));

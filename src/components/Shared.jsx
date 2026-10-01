import { Link } from 'react-router-dom';
import { Heart, ShoppingBag, ArrowUpRight, LoaderCircle, AlertCircle, Check } from 'lucide-react';
import { useApp } from '../state/AppContext';

export function ProductCard({ product }) {
  const { addToCart, wishlist, toggleWishlist } = useApp();
  const price = product.discount_price || product.price;
  return <article className="product-card"><Link className="product-image" to={`/products/${product.id}`}><img src={product.image_url || product.product_images?.[0]?.image_url || '/wood-placeholder.svg'} alt={product.name} loading="lazy"/><span className={`stock-pill ${product.stock_quantity > 0 ? 'in-stock' : ''}`}>{product.stock_quantity > 0 ? 'Available' : 'Made to order'}</span></Link><button className={`wishlist-float ${wishlist.includes(product.id) ? 'is-saved' : ''}`} onClick={() => toggleWishlist(product.id)} aria-label="Add to wishlist"><Heart size={18} fill={wishlist.includes(product.id) ? 'currentColor' : 'none'}/></button><div className="product-copy"><p className="eyebrow">{product.categories?.name || 'Woodwork'}</p><Link to={`/products/${product.id}`}><h3>{product.name}</h3></Link><div className="product-price"><strong>₹{Number(price).toLocaleString('en-IN')}</strong>{product.discount_price && <del>₹{Number(product.price).toLocaleString('en-IN')}</del>}</div><button className="button button-outline button-small" onClick={() => addToCart(product)}><ShoppingBag size={15}/> Add to cart</button></div></article>;
}
export function SectionHeading({ kicker, title, text, link, linkText = 'Explore all' }) { return <div className="section-heading"><div><p className="eyebrow">{kicker}</p><h2>{title}</h2>{text && <p className="muted">{text}</p>}</div>{link && <Link className="text-link" to={link}>{linkText}<ArrowUpRight size={16}/></Link>}</div>; }
export function Loading({ label = 'Loading…' }) { return <div className="state-box"><LoaderCircle className="spinner"/><p>{label}</p></div>; }
export function ErrorState({ message = 'Unable to load this content.' }) { return <div className="state-box error-box"><AlertCircle/><p>{message}</p><Link to="/">Return home</Link></div>; }
export function EmptyState({ title = 'Nothing here yet', text = 'This space will update as new information becomes available.' }) { return <div className="empty-state"><span><Check size={20}/></span><h3>{title}</h3><p>{text}</p></div>; }

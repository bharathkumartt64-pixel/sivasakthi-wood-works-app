import { lazy, Suspense } from 'react';
import { Navigate, Route, Routes } from 'react-router-dom';
import { Layout } from './components/Layout';
import ConfigNotice from './components/ConfigNotice';
import { useApp } from './state/AppContext';
import { Loading } from './components/Shared';

const HomePage = lazy(() => import('./pages/StorePagesFresh').then(module => ({ default: module.HomePage })));
const ProductsPage = lazy(() => import('./pages/StorePagesFresh').then(module => ({ default: module.ProductsPage })));
const ProductPage = lazy(() => import('./pages/StorePagesFresh').then(module => ({ default: module.ProductPage })));
const CategoriesPage = lazy(() => import('./pages/StorePagesFresh').then(module => ({ default: module.CategoriesPage })));
const ServicesPage = lazy(() => import('./pages/StorePagesFresh').then(module => ({ default: module.ServicesPage })));
const GalleryPage = lazy(() => import('./pages/StorePagesFresh').then(module => ({ default: module.GalleryPage })));
const AboutPage = lazy(() => import('./pages/StorePagesFresh').then(module => ({ default: module.AboutPage })));
const QuotePage = lazy(() => import('./pages/StorePagesFresh').then(module => ({ default: module.QuotePage })));
const ContactPage = lazy(() => import('./pages/StorePagesFresh').then(module => ({ default: module.ContactPage })));
const AuthPage = lazy(() => import('./pages/AccountPagesNew').then(module => ({ default: module.AuthPage })));
const ProfilePage = lazy(() => import('./pages/AccountPagesNew').then(module => ({ default: module.ProfilePage })));
const CartPage = lazy(() => import('./pages/AccountPagesNew').then(module => ({ default: module.CartPage })));
const WishlistPage = lazy(() => import('./pages/AccountPagesNew').then(module => ({ default: module.WishlistPage })));
const OrdersPage = lazy(() => import('./pages/AccountPagesNew').then(module => ({ default: module.OrdersPage })));
const OrderDetailPage = lazy(() => import('./pages/AccountPagesNew').then(module => ({ default: module.OrderDetailPage })));
const CheckoutPage = lazy(() => import('./pages/AccountPagesNew').then(module => ({ default: module.CheckoutPage })));
const AdminPages = lazy(() => import('./pages/AdminPages'));

function AccountGuard({ children }) {
  const { session, authLoading } = useApp();
  if (authLoading) return <div className="container page-state"><Loading label="Checking your account…"/></div>;
  return session ? children : <Navigate to="/login" replace/>;
}

function AdminGuard() {
  const { session, profile, authLoading } = useApp();
  if (authLoading) return <div className="container page-state"><Loading label="Checking administrator access…"/></div>;
  if (!session) return <Navigate to="/login?next=/admin" replace/>;
  if (!profile) return <div className="container page-state"><Loading label="Loading your access level…"/></div>;
  return profile.role === 'admin' ? <AdminPages/> : <div className="container page-state"><div className="success-card"><h2>Administrator access required</h2><p>This page is available to authorized administrators only.</p></div></div>;
}

function PageFallback() { return <div className="container page-state"><Loading label="Loading page…"/></div>; }

export default function App() {
  return <><ConfigNotice/><Suspense fallback={<PageFallback/>}><Routes><Route element={<Layout/>}><Route index element={<HomePage/>}/><Route path="products" element={<ProductsPage/>}/><Route path="products/:id" element={<ProductPage/>}/><Route path="categories" element={<CategoriesPage/>}/><Route path="services" element={<ServicesPage/>}/><Route path="gallery" element={<GalleryPage/>}/><Route path="about" element={<AboutPage/>}/><Route path="quote" element={<QuotePage/>}/><Route path="contact" element={<ContactPage/>}/><Route path="login" element={<AuthPage/>}/><Route path="signup" element={<AuthPage mode="signup"/>}/><Route path="forgot-password" element={<AuthPage mode="forgot"/>}/><Route path="reset-password" element={<AuthPage mode="reset"/>}/><Route path="profile" element={<AccountGuard><ProfilePage/></AccountGuard>}/><Route path="cart" element={<AccountGuard><CartPage/></AccountGuard>}/><Route path="wishlist" element={<AccountGuard><WishlistPage/></AccountGuard>}/><Route path="checkout" element={<AccountGuard><CheckoutPage/></AccountGuard>}/><Route path="orders" element={<AccountGuard><OrdersPage/></AccountGuard>}/><Route path="orders/:id" element={<AccountGuard><OrderDetailPage/></AccountGuard>}/><Route path="admin/*" element={<AdminGuard/>}/><Route path="*" element={<div className="container page-state"><div className="success-card"><h1>Page not found</h1><p>The page may have moved. Let’s get you home.</p><a className="button button-dark" href="/">Back to home</a></div></div>}/></Route></Routes></Suspense></>;
}

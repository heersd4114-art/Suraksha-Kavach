from functools import wraps
from django.http import JsonResponse
from .models import UserProfile

def role_required(allowed_roles):
    """
    Decorator for views that checks if the user has the required role.
    Assumes the user's UID is passed in the request header or body as 'X-User-ID'.
    """
    def decorator(view_func):
        @wraps(view_func)
        def _wrapped_view(request, *args, **kwargs):
            # 1. Get User ID from Header (Secure) or Body (Fallback)
            uid = request.headers.get('X-User-ID')
            
            if not uid:
                # Fallback to GET/POST params for dev testing
                uid = request.GET.get('uid') or request.POST.get('uid')

            if not uid:
                return JsonResponse({'error': 'Authentication required. No User ID provided.'}, status=401)

            # 2. Check Database for Role
            try:
                user = UserProfile.objects.get(uid=uid)
            except UserProfile.DoesNotExist:
                return JsonResponse({'error': 'User profile not found.'}, status=404)

            # 3. Verify Active Status (Enterprise Security)
            if not user.is_active:
                return JsonResponse({'error': 'Account has been deactivated.'}, status=403)

            # 4. Check Role
            # allowed_roles can be a list ['owner', 'admin'] or a single string 'owner'
            roles = allowed_roles if isinstance(allowed_roles, list) else [allowed_roles]
            
            if user.role.lower() not in [r.lower() for r in roles]:
                return JsonResponse({
                    'error': 'Access Denied: Insufficient Permissions',
                    'required_role': roles,
                    'current_role': user.role
                }, status=403)

            # 5. Attach user object to request for the view to use
            request.user_profile = user
            return view_func(request, *args, **kwargs)

        return _wrapped_view
    return decorator

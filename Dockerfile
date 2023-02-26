FROM public.ecr.aws/nginx/nginx:1.22-alpine
COPY ./index.html /usr/share/nginx/html
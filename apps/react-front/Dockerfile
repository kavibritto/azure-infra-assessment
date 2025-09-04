FROM public.ecr.aws/nginx/nginx:1.29-alpine

WORKDIR /usr/share/nginx/html

COPY dist/. .

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
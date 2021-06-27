FROM ubuntu:20.04
COPY install_script.sh /
RUN bash /install_script.sh
RUN printf "  [INFO] Removing install script from final image\n" && \
    rm /install_script.sh
COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
CMD ["ghost"]
